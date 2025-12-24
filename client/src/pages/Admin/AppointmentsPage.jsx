import React, { useEffect, useState } from 'react';
import { Layout, Table, Tag, Space, Button, Modal, Descriptions } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';

const { Content } = Layout;

const AppointmentsPage = () => {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState(null);
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
      try {
        const res = await axiosPrivate.get('/api/admin/appointments');
        const appointmentsData = unwrapListResponse(res);
        setAppointments(appointmentsData);
      } catch (error) {
        console.error('Error fetching appointments:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách lịch hẹn';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa lịch hẹn này?')) {
      try {
        // Note: Cần thêm endpoint DELETE /api/admin/appointments/{id} nếu cần
        showMessage.info('Chức năng xóa lịch hẹn đang được phát triển');
      } catch (error) {
        console.error('Error deleting appointment:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa lịch hẹn';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = [
    { 
      title: 'ID', 
      dataIndex: 'id', 
      key: 'id', 
      width: 80 
    },
    { 
      title: 'Người dùng', 
      dataIndex: 'userName', 
      key: 'userName',
      render: (text, record) => (
        <span style={{ color: '#fff' }}>
          {text || `User ID: ${record.userId}`}
        </span>
      )
    },
    { 
      title: 'Tiêu đề', 
      dataIndex: 'title', 
      key: 'title',
      ellipsis: true,
      render: (text) => <span style={{ color: '#fff' }}>{text}</span>
    },
    { 
      title: 'Thời gian hẹn', 
      dataIndex: 'appointmentTime', 
      key: 'appointmentTime',
      render: (date) => (
        <span style={{ color: '#fff' }}>
          {date ? new Date(date).toLocaleString('vi-VN') : 'N/A'}
        </span>
      )
    },
    { 
      title: 'Nhắc trước', 
      dataIndex: 'reminderMinutes', 
      key: 'reminderMinutes',
      render: (minutes) => (
        <span style={{ color: '#fff' }}>
          {minutes} phút
        </span>
      )
    },
    { 
      title: 'Đã thông báo', 
      dataIndex: 'isNotified', 
      key: 'isNotified',
      render: (isNotified) => (
        <Tag color={isNotified ? 'green' : 'orange'}>
          {isNotified ? 'Đã thông báo' : 'Chưa thông báo'}
        </Tag>
      )
    },
    { 
      title: 'Trạng thái', 
      dataIndex: 'isCanceled', 
      key: 'isCanceled',
      render: (isCanceled) => (
        <Tag color={isCanceled ? 'red' : 'green'}>
          {isCanceled ? 'Đã hủy' : 'Hoạt động'}
        </Tag>
      )
    },
    { 
      title: 'Thời gian tạo', 
      dataIndex: 'createdAt', 
      key: 'createdAt',
      render: (date) => (
        <span style={{ color: '#fff' }}>
          {date ? new Date(date).toLocaleString('vi-VN') : 'N/A'}
        </span>
      )
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 120,
      render: (_, record) => (
        <Space>
          <Button onClick={() => setDetail(record)}>Xem</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/appointments" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý lịch hẹn</h1>
          <Table 
            columns={columns} 
            dataSource={appointments} 
            loading={loading} 
            rowKey="id" 
            style={{ marginTop: 24 }}
            pagination={{ pageSize: 20 }}
          />
          <Modal 
            open={!!detail} 
            onCancel={() => setDetail(null)} 
            footer={null} 
            title="Chi tiết lịch hẹn"
            width={600}
          >
            {detail && (
              <Descriptions bordered column={1} size="small">
                <Descriptions.Item label="ID">{detail.id}</Descriptions.Item>
                <Descriptions.Item label="Người dùng">
                  {detail.userName || `User ID: ${detail.userId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Tiêu đề">{detail.title}</Descriptions.Item>
                <Descriptions.Item label="Mô tả">
                  {detail.description || 'Không có mô tả'}
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian hẹn">
                  {detail.appointmentTime ? new Date(detail.appointmentTime).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Nhắc trước">
                  {detail.reminderMinutes} phút
                </Descriptions.Item>
                <Descriptions.Item label="Đã thông báo">
                  <Tag color={detail.isNotified ? 'green' : 'orange'}>
                    {detail.isNotified ? 'Đã thông báo' : 'Chưa thông báo'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Tag color={detail.isCanceled ? 'red' : 'green'}>
                    {detail.isCanceled ? 'Đã hủy' : 'Hoạt động'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian tạo">
                  {detail.createdAt ? new Date(detail.createdAt).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
              </Descriptions>
            )}
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default AppointmentsPage;

